// entry/src/main/ets/api/message.ets
import { http } from '../common/utils/Request';

export interface MessageItem {
  id: number;
  type: string;
  title: string;
  content: string;
  created_at: number;
  is_read: number;
  extra?: string;
}

export interface MessageListResp {
  list: MessageItem[];
}

// ⭐ 未读数量响应类型
class UnreadCountResp {
  count: number = 0;
}

// ⭐ 未读数量请求参数
class UnreadCountParam {
  userId: string = '';
}

// ⭐ 消息列表请求参数
class MessageListParam {
  userId: string = '';
}

// ⭐ 全部已读请求参数
class ReadAllParam {
  userId: string = '';
}

// =================== API 实现 ===================

// 获取未读数量（前端只用来判断 >0 画小红点）
export const getUnreadCountApi = (userId: string): Promise<number> => {
  const param = new UnreadCountParam();
  param.userId = userId;

  return http
    .get<UnreadCountResp>('/auth/message/unreadCount', param)
    .then((res: UnreadCountResp) => res.count ?? 0);
};

// 获取消息列表
export const getMessageListApi = (userId: string): Promise<MessageItem[]> => {
  const param = new MessageListParam();
  param.userId = userId;

  return http
    .get<MessageListResp>('/auth/message/list', param)
    .then((res: MessageListResp) => res.list ?? []);
};

// 全部标记已读（用来清小红点）
export const readAllMessagesApi = (userId: string): Promise<void> => {
  const body = new ReadAllParam();
  body.userId = userId;

  return http.post<void>('/auth/message/readAll', body);
};
